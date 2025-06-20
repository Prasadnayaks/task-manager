import { Router } from "express";
import { auth, AuthRequest } from "../middleware/auth";
import { NewTask, tasks } from "../db/schema";
import { db } from "../db";
import { eq, and } from "drizzle-orm";

const taskRouter = Router();

// CREATE A TASK
taskRouter.post("/", auth, async (req: AuthRequest, res) => {
  try {
    req.body = { ...req.body, dueAt: new Date(req.body.dueAt), uid: req.user };
    const newTask: NewTask = req.body;
    const [task] = await db.insert(tasks).values(newTask).returning();
    res.status(201).json(task);
  } catch (e: any) {
    console.error("Error creating task:", e.message);
    res.status(500).json({ error: "Failed to create task." });
  }
});

// GET ALL TASKS
taskRouter.get("/", auth, async (req: AuthRequest, res) => {
  try {
    const allTasks = await db
      .select()
      .from(tasks)
      .where(eq(tasks.uid, req.user!));
    res.json(allTasks);
  } catch (e: any) {
    console.error("Error fetching tasks:", e.message);
    res.status(500).json({ error: "Failed to fetch tasks." });
  }
});

// UPDATE A TASK
taskRouter.put("/:id", auth, async (req: AuthRequest, res) => {
  try {
    const taskId = req.params.id;
    const { title, description, hexColor, dueAt } = req.body;

    const [updatedTask] = await db
      .update(tasks)
      .set({
        title,
        description,
        hexColor,
        dueAt: new Date(dueAt),
        updatedAt: new Date(),
      })
      .where(and(eq(tasks.id, taskId), eq(tasks.uid, req.user!)))
      .returning();

    if (!updatedTask) {
      res.status(404).json({ error: "Task not found or user not authorized." });
      return;
    }

    res.json(updatedTask);
  } catch (e: any) {
    console.error("Error updating task:", e.message);
    res.status(500).json({ error: "Failed to update task." });
  }
});

// DELETE A TASK
taskRouter.delete("/:id", auth, async (req: AuthRequest, res) => {
  try {
    const taskId = req.params.id;

    const [deletedTask] = await db
      .delete(tasks)
      .where(and(eq(tasks.id, taskId), eq(tasks.uid, req.user!)))
      .returning();
    
    if (!deletedTask) {
      res.status(404).json({ error: "Task not found or user not authorized." });
      return;
    }

    res.json({ success: true, id: deletedTask.id });
  } catch (e: any) {
    console.error("Error deleting task:", e.message);
    res.status(500).json({ error: "Failed to delete task." });
  }
});

// SYNC TASKS
taskRouter.post("/sync", auth, async (req: AuthRequest, res) => {
  try {
    const tasksList = req.body;
    const filteredTasks: NewTask[] = [];

    for (let t of tasksList) {
      t = {
        ...t,
        dueAt: new Date(t.dueAt),
        createdAt: new Date(t.createdAt),
        updatedAt: new Date(t.updatedAt),
        uid: req.user,
      };
      filteredTasks.push(t);
    }

    const pushedTasks = await db
      .insert(tasks)
      .values(filteredTasks)
      .returning();

    res.status(201).json(pushedTasks);
  } catch (e: any) {
    console.error("Error syncing tasks:", e.message);
    res.status(500).json({ error: "Failed to sync tasks." });
  }
});

export default taskRouter;